function [all_possible_variables,all_possible_display_names] = give_possible_variables_to_SEGGA_polarity()


all_possible_variables = {...
        'polarity_basic_tag_name_dependent',...
        'polarity_normed_tag_name_dependent',...
        ...'polarity_orderscore_tag_name_dependent',...
        'cortical_to_cyto'...
%         'polarity_spatial_correlation'...
        };


all_possible_display_names = {...
        'Cell Polarity (Log2) - by tag names',...
        'Cell Polarity Normalized to Max (Log2) - by tag names',...
        ...'Angular Order of Edge Intensities - by tag names',...
        'Cortical to Cytoplasmic Intensity Ratio (Log2) - by tag names'...
%         'Spatial Correlation of Cell Polarity'...
        };


    

